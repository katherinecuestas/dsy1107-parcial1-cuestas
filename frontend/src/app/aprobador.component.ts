import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from './api.service';

@Component({
  selector: 'app-aprobador',
  standalone: true,
  imports: [FormsModule],
  template: `
    <section class="tarjeta">
      <h2>Solicitudes pendientes</h2>
      <button (click)="cargar()">Actualizar</button>
      @for (s of pendientes(); track s) {
        <div class="resultado">
          <p><strong>{{ s.tipo }}</strong> — de {{ s.solicitanteEmail }}</p>
          <p>{{ s.fechaInicio }} a {{ s.fechaFin }}</p>
          <input [(ngModel)]="comentarios[s.id]" placeholder="Comentario" />
          <button (click)="aprobar(s.id)">Aprobar</button>
          <button class="peligro" (click)="rechazar(s.id)">Rechazar</button>
        </div>
      }
      @if (pendientes().length === 0) {
        <p>No hay solicitudes pendientes.</p>
      }
    </section>
  `,
})
export class AprobadorComponent implements OnInit {
  private readonly api = inject(ApiService);

  protected readonly pendientes = signal<any[]>([]);
  protected comentarios: Record<number, string> = {};

  ngOnInit(): void {
    this.cargar();
  }

  async cargar(): Promise<void> {
    const resultado = await this.api.solicitudesPendientes();
    this.pendientes.set((resultado.cuerpo as any[]) ?? []);
  }

  async aprobar(id: number): Promise<void> {
    await this.api.aprobarSolicitud(id, this.comentarios[id] ?? '');
    await this.cargar();
  }

  async rechazar(id: number): Promise<void> {
    await this.api.rechazarSolicitud(id, this.comentarios[id] ?? '');
    await this.cargar();
  }
}