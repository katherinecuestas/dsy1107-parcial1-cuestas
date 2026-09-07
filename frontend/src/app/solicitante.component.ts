import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from './api.service';

@Component({
  selector: 'app-solicitante',
  standalone: true,
  imports: [FormsModule],
  template: `
    <section class="tarjeta">
      <h2>Crear solicitud</h2>
      <label>Tipo: <input [(ngModel)]="tipo" placeholder="vacaciones" /></label>
      <label>Fecha inicio: <input type="date" [(ngModel)]="fechaInicio" /></label>
      <label>Fecha fin: <input type="date" [(ngModel)]="fechaFin" /></label>
      <button (click)="crear()">Enviar solicitud</button>
    </section>

    <section class="tarjeta">
      <h2>Mis solicitudes</h2>
      <button (click)="cargar()">Actualizar</button>
      @for (s of misSolicitudes(); track s) {
        <div class="resultado">
          <p><strong>{{ s.tipo }}</strong> — {{ s.estado }}</p>
          <p>{{ s.fechaInicio }} a {{ s.fechaFin }}</p>
          @if (s.comentario) {
            <p><em>Comentario: {{ s.comentario }}</em></p>
          }
        </div>
      }
    </section>
  `,
})
export class SolicitanteComponent implements OnInit {
  private readonly api = inject(ApiService);

  protected tipo = '';
  protected fechaInicio = '';
  protected fechaFin = '';
  protected readonly misSolicitudes = signal<any[]>([]);

  ngOnInit(): void {
    this.cargar();
  }

  async crear(): Promise<void> {
    if (!this.tipo || !this.fechaInicio || !this.fechaFin) return;
    await this.api.crearSolicitud(
      this.tipo,
      new Date(this.fechaInicio).toISOString(),
      new Date(this.fechaFin).toISOString(),
    );
    this.tipo = '';
    this.fechaInicio = '';
    this.fechaFin = '';
    await this.cargar();
  }

  async cargar(): Promise<void> {
    const resultado = await this.api.misSolicitudes();
    this.misSolicitudes.set((resultado.cuerpo as any[]) ?? []);
  }
}