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
      @for (s of misSolicitudes(); track s.id) {
        <div class="resultado">
          @if (editandoId() === s.id) {
            <!-- Modo edicion: reemplaza los datos por un mini-formulario -->
            <input [(ngModel)]="tipoEdit" placeholder="tipo" />
            <input type="date" [(ngModel)]="fechaInicioEdit" />
            <input type="date" [(ngModel)]="fechaFinEdit" />
            <button (click)="guardarEdicion(s.id)">Guardar</button>
            <button (click)="cancelarEdicion()">Cancelar edicion</button>
          } @else {
            <p><strong>{{ s.tipo }}</strong> — {{ s.estado }}</p>
            <p>{{ s.fechaInicio }} a {{ s.fechaFin }}</p>
            @if (s.comentario) {
              <p><em>Comentario: {{ s.comentario }}</em></p>
            }
            @if (s.estado === 'PENDIENTE') {
              <button (click)="iniciarEdicion(s)">Editar</button>
              <button class="peligro" (click)="cancelar(s.id)">Cancelar solicitud</button>
            }
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

  // Estado de edicion: cual solicitud se esta editando (o null si ninguna)
  protected readonly editandoId = signal<number | null>(null);
  protected tipoEdit = '';
  protected fechaInicioEdit = '';
  protected fechaFinEdit = '';

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

  iniciarEdicion(s: any): void {
    this.editandoId.set(s.id);
    this.tipoEdit = s.tipo;
    this.fechaInicioEdit = s.fechaInicio.substring(0, 10);
    this.fechaFinEdit = s.fechaFin.substring(0, 10);
  }

  cancelarEdicion(): void {
    this.editandoId.set(null);
  }

  async guardarEdicion(id: number): Promise<void> {
    await this.api.editarSolicitud(
      id,
      this.tipoEdit,
      new Date(this.fechaInicioEdit).toISOString(),
      new Date(this.fechaFinEdit).toISOString(),
    );
    this.editandoId.set(null);
    await this.cargar();
  }

  async cancelar(id: number): Promise<void> {
    await this.api.cancelarSolicitud(id);
    await this.cargar();
  }
}